output "controle_plnae_lb" {
  description = "The DNS name of LB for controle plane"
  value = module.controle_plane.lb_dns_name
}
