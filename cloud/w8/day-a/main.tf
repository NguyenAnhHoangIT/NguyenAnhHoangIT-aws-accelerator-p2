module "network" {
  source = "./modules/network"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
}

module "web" {
  source = "./modules/web"

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  environment       = var.environment
}

module "data" {
  source = "./modules/data"

  vpc_id              = module.network.vpc_id
  database_subnet_ids = module.network.public_subnet_ids
  web_sg_id           = module.web.web_sg_id
  environment         = var.environment
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  db_password_version = var.db_password_version
}
