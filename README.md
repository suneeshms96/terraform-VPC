

## Infrastructure as code in AWS using terraform

### An infrastructure to deploy three instances namely tf_bastion, tf_public and tf_private respectively.

### A custom VPC with two public and a private subnet is setup.

### The instances tf_public  and tf_bastion are created on public subnet and tf_private on private subnet.

### tf_public is for webserver  and tf_private for database.

### A NAT gateway is created and an Elastic IP is allocated.

### Security groups are created for each instances and route tables are configured.

### Userdata scripts are added for instances webserver and database.


Execution
=========

***terraform validate***   - Syntax check.

***terraform plan*** - Creating an execution plan.

***terraform apply*** - Apply the changes.

***terraform destroy*** - Destroy the terraform managed infrastructure.
