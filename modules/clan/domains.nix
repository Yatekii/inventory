# Central domain configuration for all services
let
  domains = [
    {
      name = "huesser.dev";
      primary = true;
    }
    {
      name = "jarty.ch";
      primary = false;
    }
  ];
  primaryDomainRecord = builtins.head (builtins.filter (d: d.primary) domains);
in
{
  inherit domains;
  primaryDomain = primaryDomainRecord.name;
}
