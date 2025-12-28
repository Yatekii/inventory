use std::{
    collections::HashMap,
    fs::DirEntry,
    ops::{Deref, DerefMut},
    path::{Path, PathBuf},
};

use anyhow::{Context, Ok, Result, anyhow};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use xshell::{Shell, cmd};

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[clap(long)]
    root: PathBuf,
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand, Debug)]
enum Command {
    DeriveMachinesJson {
        /// The tofu binary
        tofu: PathBuf,
        /// The terraform.tfstate
        terraform_state: PathBuf,
        /// The machines.json
        machines_json: PathBuf,
    },
    GatherDiskIds {
        /// The machines.json
        machines_json: PathBuf,
    },
    GatherTerraformFiles {
        /// The machines directory
        machines: PathBuf,
        /// The directory of all the terraform files
        terraform: PathBuf,
    },
    CleanTerraformFiles {
        /// The directory of all the terraform files
        terraform: PathBuf,
    },
}

fn main() -> Result<()> {
    let args = Args::parse();

    match args.command {
        Command::DeriveMachinesJson {
            tofu,
            terraform_state,
            machines_json,
        } => derive_machines_json(args.root, tofu, terraform_state, machines_json)?,
        Command::GatherDiskIds { machines_json } => gather_disk_ids(args.root, machines_json)?,
        Command::GatherTerraformFiles {
            machines,
            terraform,
        } => gather_terraform_files(args.root, machines, terraform)?,
        Command::CleanTerraformFiles { terraform } => clean_terraform_files(args.root, terraform)?,
    }

    Ok(())
}

fn clean_terraform_files(root: PathBuf, terraform: PathBuf) -> Result<()> {
    std::env::set_current_dir(&root)?;

    visit_dirs(&terraform, &|file| {
        if file.path().extension().unwrap_or_default() == "tf"
            && file.file_name().to_string_lossy().starts_with("_")
        {
            std::fs::remove_file(file.path())
                .with_context(|| anyhow!("{file:?} could not be copied"))?;
            println!("Removed {}", file.path().display());
        }
        Ok(())
    })?;

    Ok(())
}

/// Get all the terraform files that describe the machines and copy them into the same tree.
/// This is required because terraform has horrible file management and we want to keep the
/// terraform files close to the machine spec.
/// Because terraform has no includes, we copy the files to the right place with this command
/// to then run terraform and clean up the files later.
fn gather_terraform_files(root: PathBuf, machines: PathBuf, terraform: PathBuf) -> Result<()> {
    std::env::set_current_dir(&root)?;

    visit_dirs(&machines, &|file| {
        if file.path().extension().unwrap_or_default() == "tf" {
            std::fs::copy(
                file.path(),
                terraform.join(
                    Path::new(&format!(
                        "_{}",
                        file.path().parent().unwrap().file_stem().unwrap().display()
                    ))
                    .with_extension("tf"),
                ),
            )
            .with_context(|| anyhow!("{file:?} could not be copied"))?;
            println!("Copied {}", file.path().display());
        }
        Ok(())
    })?;

    Ok(())
}

fn gather_disk_ids(root: PathBuf, machines_json: PathBuf) -> Result<()> {
    std::env::set_current_dir(&root)?;
    let sh = Shell::new()?;
    let mut machines = Machines::load(machines_json)?;

    for (_, machine) in machines.iter_mut() {
        let ip = &machine.ipv4;
        let host = format!("root@{ip}");
        println!("grabbing diskId for {host}");

        // Retry SSH connection up to 30 times with 2 second delay (60s total)
        let mut disk_id_output = String::new();
        for attempt in 1..=30 {
            let result = cmd!(
                sh,
                "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 root@{ip} lsblk --output NAME,ID-LINK"
            )
            .read();

            match result {
                std::result::Result::Ok(output) => {
                    disk_id_output = output;
                    break;
                }
                std::result::Result::Err(_) if attempt < 30 => {
                    println!("  SSH not ready, retrying in 2s... (attempt {attempt}/30)");
                    std::thread::sleep(std::time::Duration::from_secs(2));
                }
                std::result::Result::Err(e) => return Err(e.into()),
            }
        }
        for line in disk_id_output.lines() {
            if line.starts_with("sda") {
                machine.disk_id = line.split_ascii_whitespace().nth(1).unwrap().to_string();
            }
        }
        if machine.disk_id.is_empty() {
            panic!("not able to determine disk id");
        }
    }

    machines.store()
}

fn derive_machines_json(
    root: PathBuf,
    tofu: PathBuf,
    terraform_state: PathBuf,
    machines_json: PathBuf,
) -> Result<()> {
    std::env::set_current_dir(&root)?;
    let sh = Shell::new()?;
    let json = cmd!(sh, "{tofu} show -json {terraform_state}")
        .read()
        .with_context(|| anyhow!("terraform could not generate state"))?;
    let json: Value = serde_json::from_str(&json)?;
    let resources = &json["values"]["root_module"]["resources"];
    let mut machines = Machines::new(machines_json);
    for server in resources
        .as_array()
        .with_context(|| anyhow!("resources was not an array"))?
        .iter()
        .filter(|v| v["type"] == "hcloud_server")
    {
        let name = server["name"]
            .as_str()
            .with_context(|| anyhow!("name was not a string"))?
            .to_string();
        let ip = server["values"]["ipv4_address"]
            .as_str()
            .with_context(|| anyhow!("ip was not a string"))?
            .to_string();
        machines.insert(
            name,
            Machine {
                ipv4: ip,
                ..Default::default()
            },
        );
    }

    machines.store()
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct Machine {
    ipv4: String,
    disk_id: String,
}

#[derive(Debug, Default)]
struct Machines {
    machines_json: PathBuf,
    machines: HashMap<String, Machine>,
}

impl Machines {
    fn load(machines_json: PathBuf) -> Result<Self> {
        let json = std::fs::read_to_string(&machines_json)
            .with_context(|| anyhow!("'{machines_json:?}' could not be opened"))?;
        let machines: HashMap<String, Machine> = serde_json::from_str(&json)
            .with_context(|| anyhow!("machines.json could not be parsed"))?;

        Ok(Machines {
            machines_json,
            machines,
        })
    }

    fn store(&self) -> Result<()> {
        std::fs::write(
            &self.machines_json,
            serde_json::to_string_pretty(&self.machines)
                .with_context(|| anyhow!("json could not be serialized"))?,
        )
        .with_context(|| anyhow!("'{:?}' could not be written", self.machines_json))?;
        Ok(())
    }

    fn new(machines_json: PathBuf) -> Self {
        Self {
            machines_json,
            machines: Default::default(),
        }
    }
}

impl Deref for Machines {
    type Target = HashMap<String, Machine>;

    fn deref(&self) -> &Self::Target {
        &self.machines
    }
}

impl DerefMut for Machines {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.machines
    }
}

fn visit_dirs(dir: &Path, cb: &impl Fn(&DirEntry) -> Result<()>) -> Result<()> {
    if dir.is_dir() {
        for entry in std::fs::read_dir(dir)? {
            let entry = entry?;
            let path = entry.path();
            if path.is_dir() {
                visit_dirs(&path, cb)?;
            } else {
                cb(&entry)?;
            }
        }
    }
    Ok(())
}
