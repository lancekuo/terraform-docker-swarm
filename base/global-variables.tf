variable "subnets" {
    type = "map"
    default = {
        dev           = "10.14.0.0/16"
        qa            = "10.13.0.0/16"
        stg           = "10.12.0.0/16"
        prd           = "10.10.0.0/16"
        app.dev       = "10.14.20.0/23"
        app.qa        = "10.13.20.0/23"
        app.stg       = "10.12.20.0/23"
        app.prd       = "10.10.20.0/23"
        app_1.dev     = "10.14.20.0/24"
        app_1.qa      = "10.13.20.0/24"
        app_1.stg     = "10.12.20.0/24"
        app_1.prd     = "10.10.20.0/24"
        app_2.dev     = "10.14.21.0/24"
        app_2.qa      = "10.13.21.0/24"
        app_2.stg     = "10.12.21.0/24"
        app_2.prd     = "10.10.21.0/24"
        public.dev    = "10.14.10.0/23"
        public.qa     = "10.13.10.0/23"
        public.stg    = "10.12.10.0/23"
        public.prd    = "10.10.10.0/23"
        public_1.dev  = "10.14.10.0/24"
        public_1.qa   = "10.13.10.0/24"
        public_1.stg  = "10.12.10.0/24"
        public_1.prd  = "10.10.10.0/24"
        public_2.dev  = "10.14.11.0/24"
        public_2.qa   = "10.13.11.0/24"
        public_2.stg  = "10.12.11.0/24"
        public_2.prd  = "10.10.11.0/24"
        private_1.dev = "10.14.50.0/24"
        private_1.qa  = "10.13.50.0/24"
        private_1.stg = "10.12.50.0/24"
        private_1.prd = "10.10.50.0/24"
        private_2.dev = "10.14.51.0/24"
        private_2.qa  = "10.13.51.0/24"
        private_2.stg = "10.12.51.0/24"
        private_2.prd = "10.10.51.0/24"
    }
}
variable "aws_amis" {
    default = {
        "eu-west-1"    = "ami-a8d2d7ce",
        "eu-west-2"    = "ami-f1d7c395",
        "us-east-1"    = "ami-80861296",
        "us-east-2"    = "ami-618fab04",
        "us-west-1"    = "ami-2afbde4a",
        "us-west-2"    = "ami-efd0428f",
        "ca-central-1" = "ami-b3d965d7"
    }
}
data "aws_availability_zones" "azs" {}

