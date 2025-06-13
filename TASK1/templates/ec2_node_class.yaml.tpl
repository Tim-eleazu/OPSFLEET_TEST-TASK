apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${name}
spec:
  amiFamily: ${ami_family}
  amiSelectorTerms:
    - alias: ${ami_selector}

  subnetSelectorTerms:
%{ if use_subnet_ids }
%{ for subnet_id in subnet_ids ~}
    - id: ${subnet_id}
%{ endfor }
%{ else }
    - tags:
        karpenter.sh/discovery: ${cluster_name}
%{ endif }

  securityGroupSelectorTerms:
%{ if use_security_group_ids }
%{ for sg_id in security_group_ids ~}
    - id: ${sg_id}
%{ endfor }
%{ else }
    - tags:
        karpenter.sh/discovery: ${cluster_name}
%{ endif }

  role: ${node_role_arn}
  tags:
    karpenter.sh/discovery: ${cluster_name}

  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: ${disk_size}
        volumeType: gp3
        encrypted: true
        deleteOnTermination: true

  metadataOptions:
    httpEndpoint: enabled
    httpTokens: required
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 2

  detailedMonitoring: false
