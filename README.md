Website DNS name -  test-elb-619840623.us-east-1.elb.amazonaws.com


High Available and scalable - added Auto scaling group
Fault Tolerance -  added Load Balancer
Secure  -  Created Custom VPC


Firstly i have created custom VPC to make website more secure,after that i have created security group to open port and allow Web inbound traffic.Load balancer is created for fault tolerance its check health of targeted instances if any instance fail, it will not send traffic to that instance.Launch template is created for EC2 instance.Auto scaling group is created and launch template is attached to it.it will make Website high available and scalable.
