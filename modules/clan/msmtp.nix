{ config, ... }:
let
  fastmailPasswordPath = config.clan.core.vars.generators.fastmail-smtp.files.password.path;
in
{
  # msmtp as a send-only relay via Fastmail. Provides the `sendmail` ABI
  # so ZED, smartd, systemd `OnFailure=` mail templates and anything else
  # expecting local mail delivery works without a full MTA. No local queue
  # — if Fastmail is unreachable, the message is dropped. Acceptable for
  # alerting, where recency > durability.
  #
  # App-specific passwords only (fastmail.com/settings/security/devicepasswords);
  # the main account password won't work with 2FA enabled.

  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/etc/aliases";
      port = 465;
      tls = "on";
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      auth = "on";
    };
    accounts.default = {
      host = "smtp.fastmail.com";
      from = "noah@huesser.dev";
      user = "noah@huesser.dev";
      passwordeval = "cat ${fastmailPasswordPath}";
    };
  };

  # Shared across every host that imports this module — one Fastmail app
  # password covers saru/aiur/fenix. Rotate by re-prompting: remove the
  # existing var and re-run `clan vars generate <machine>`.
  clan.core.vars.generators.fastmail-smtp = {
    share = true;
    prompts.password = {
      description = "Fastmail SMTP app-specific password (fastmail.com/settings/security/devicepasswords)";
      type = "hidden";
      persist = true;
    };
    files.password = {
      secret = true;
      owner = "root";
      mode = "0400";
    };
  };

  # Route local root mail to the user's inbox.
  environment.etc."aliases".text = ''
    root: noah@huesser.dev
  '';
}
