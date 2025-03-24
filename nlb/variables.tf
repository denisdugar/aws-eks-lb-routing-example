variable "instances" {
  type    = list(string)
  description = "This variable contains list of instances IDs for creating attachments in Target group"
  default = ["i-0e4fe013e0ae47776", "i-0bd799fa70c897516", "i-0d3e6b553892ef22f"]
}

