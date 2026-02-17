from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Fargate, Lambda
from diagrams.aws.database import Dynamodb
from diagrams.aws.integration import SNS, SQS
from diagrams.aws.management import AmazonDevopsGuru, CloudwatchAlarm, CloudwatchLogs
from diagrams.aws.storage import S3

with Diagram("DevOps Agent Demo - Order Processing", filename="generated-diagrams/diagram", show=False, direction="LR"):

    with Cluster("ECS Frontend"):
        ecs = Fargate("ECS\nFargate")

    sns = SNS("SNS\nOrders")
    sqs = SQS("SQS\nProcessing")

    with Cluster("Order Processor"):
        lam = Lambda("Lambda\nProcessor")

    with Cluster("Data Stores"):
        ddb = Dynamodb("DynamoDB\nOrders")
        s3 = S3("S3\nReceipts")

    with Cluster("Monitoring"):
        cw_alarm = CloudwatchAlarm("CW Alarms")
        cw_logs = CloudwatchLogs("CW Logs")

    devops = AmazonDevopsGuru("DevOps\nAgent")

    ecs >> sns >> sqs >> lam
    lam >> ddb
    lam >> Edge(color="red", style="dashed", label="FAULT: AccessDenied") >> s3
    lam >> cw_logs
    cw_alarm >> Edge(style="dotted", label="triggers investigation") >> devops
