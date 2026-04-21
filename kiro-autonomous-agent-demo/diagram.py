from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.database import Dynamodb
from diagrams.aws.general import User
from diagrams.aws.management import CloudwatchAlarm, CloudwatchLogs
from diagrams.aws.ml import Bedrock
from diagrams.aws.network import APIGateway, CloudFront
from diagrams.aws.storage import S3

with Diagram("Kiro Autonomous Agent Demo - Ye Olde Translator", filename="generated-diagrams/diagram", show=False, direction="LR"):

    user = User("User")

    with Cluster("Static Website"):
        cf = CloudFront("CloudFront")
        s3 = S3("S3\nWebsite")

    apigw = APIGateway("API Gateway\nHTTP API")

    with Cluster("Backend"):
        lam = Lambda("Lambda\nTranslator")

    bedrock = Bedrock("Bedrock\nClaude Haiku 4.5")

    ddb = Dynamodb("DynamoDB\nTranslations")

    with Cluster("Monitoring"):
        cw_alarm = CloudwatchAlarm("CW Alarms")
        cw_logs = CloudwatchLogs("CW Logs")

    user >> cf >> s3
    user >> apigw >> lam
    lam >> bedrock
    lam >> ddb
    lam >> cw_logs
    cw_alarm >> Edge(style="dotted", label="monitors") >> lam
