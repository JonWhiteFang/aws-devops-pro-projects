# Architecture Diagrams

## Project A: CI/CD with ECS Blue/Green

```mermaid
flowchart LR
    subgraph Source
        CC[CodeCommit]
    end
    
    subgraph Build
        CB[CodeBuild]
        ECR[ECR Repository]
    end
    
    subgraph Approval
        MA[Manual Approval]
    end
    
    subgraph Deploy
        CD[CodeDeploy]
        subgraph ECS
            Blue[Blue Tasks]
            Green[Green Tasks]
        end
        ALB[Application Load Balancer]
    end
    
    subgraph Test
        IT[Integration Tests]
    end
    
    CC --> CB
    CB --> ECR
    ECR --> MA
    MA --> CD
    CD --> Green
    ALB --> Blue
    ALB -.-> Green
    CD --> IT
```

## Project B: Config Remediation

```mermaid
flowchart TD
    subgraph AWS Config
        CR[Config Recorder]
        MR[Managed Rules]
        CUR[Custom Rule]
    end
    
    subgraph Evaluation
        Lambda[Lambda Function]
    end
    
    subgraph Remediation
        RC[Remediation Config]
        SSM[SSM Automation]
    end
    
    subgraph Resources
        EC2[EC2 Instances]
        S3[S3 Buckets]
    end
    
    CR --> MR
    CR --> CUR
    CUR --> Lambda
    Lambda --> RC
    MR --> RC
    RC --> SSM
    SSM --> EC2
    SSM --> S3
```

## Project C: Multi-Region Architecture

```mermaid
flowchart TD
    subgraph DNS
        R53[Route 53]
        HC1[Health Check A]
        HC2[Health Check B]
    end
    
    subgraph Region A - Primary
        ALB1[ALB]
        Lambda1[Lambda]
        DDB1[(DynamoDB)]
    end
    
    subgraph Region B - Secondary
        ALB2[ALB]
        Lambda2[Lambda]
        DDB2[(DynamoDB)]
    end
    
    R53 --> |Primary| ALB1
    R53 -.-> |Failover| ALB2
    HC1 --> ALB1
    HC2 --> ALB2
    ALB1 --> Lambda1
    ALB2 --> Lambda2
    Lambda1 --> DDB1
    Lambda2 --> DDB2
    DDB1 <--> |Global Table| DDB2
```

## Project D: Observability

```mermaid
flowchart LR
    subgraph Application
        App[ECS Service]
        Logs[CloudWatch Logs]
    end
    
    subgraph Metrics
        CW[CloudWatch Metrics]
        Custom[Custom Metrics EMF]
    end
    
    subgraph Alerting
        Alarm[Metric Alarms]
        Composite[Composite Alarm]
        Anomaly[Anomaly Detection]
        SNS[SNS Topic]
    end
    
    subgraph Visualization
        Dashboard[CloudWatch Dashboard]
        Insights[Logs Insights]
    end
    
    App --> Logs
    App --> CW
    App --> Custom
    Logs --> Insights
    CW --> Alarm
    CW --> Anomaly
    Alarm --> Composite
    Composite --> SNS
    Anomaly --> SNS
    CW --> Dashboard
    Custom --> Dashboard
```

## Project E: Incident Response

```mermaid
flowchart TD
    subgraph Trigger
        CWA[CloudWatch Alarm]
    end
    
    subgraph EventBridge
        EB[EventBridge Rule]
    end
    
    subgraph Automation
        SSM1[Restart ECS]
        SSM2[Recover EC2]
        SSM3[Create Snapshot]
    end
    
    subgraph OpsCenter
        OI[OpsItem]
    end
    
    subgraph Targets
        ECS[ECS Service]
        EC2[EC2 Instance]
    end
    
    CWA --> EB
    EB --> SSM1
    EB --> SSM2
    EB --> OI
    SSM1 --> ECS
    SSM2 --> EC2
    SSM3 --> EC2
```

## Project F: Governance

```mermaid
flowchart TD
    subgraph Management Account
        Org[AWS Organizations]
        CT[CloudTrail Org Trail]
        SCP[Service Control Policies]
    end
    
    subgraph Security Account
        SH[Security Hub]
        GD[GuardDuty]
        AA[Access Analyzer]
    end
    
    subgraph Member Accounts
        Dev[Dev Account]
        Prod[Prod Account]
    end
    
    Org --> SCP
    SCP --> Dev
    SCP --> Prod
    CT --> Dev
    CT --> Prod
    SH --> Dev
    SH --> Prod
    GD --> Dev
    GD --> Prod
```

## Project G: Additional Topics

### EC2 Image Builder Pipeline

```mermaid
flowchart LR
    subgraph Recipe
        Base[Base AMI]
        Comp[Components]
    end
    
    subgraph Pipeline
        Build[Build Instance]
        Test[Test Phase]
    end
    
    subgraph Distribution
        R1[Region 1 AMI]
        R2[Region 2 AMI]
    end
    
    Base --> Build
    Comp --> Build
    Build --> Test
    Test --> R1
    Test --> R2
```

### Lambda SAM Deployment

```mermaid
flowchart LR
    subgraph Source
        SAM[SAM Template]
    end
    
    subgraph Deploy
        CD[CodeDeploy]
        Pre[Pre-Traffic Hook]
        Post[Post-Traffic Hook]
    end
    
    subgraph Lambda
        V1[Version 1 - 90%]
        V2[Version 2 - 10%]
    end
    
    subgraph Monitoring
        Alarm[CloudWatch Alarms]
    end
    
    SAM --> CD
    CD --> Pre
    Pre --> V2
    V2 --> Post
    Alarm --> |Rollback| CD
```
