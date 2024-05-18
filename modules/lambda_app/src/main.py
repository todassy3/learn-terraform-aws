import os

import boto3
from slack_sdk import WebClient

SLACK_TOKEN = os.environ["SLACK_TOKEN"]
SLACK_CHANNEL = os.environ["SLACK_CHANNEL"]
TABLE_NAME = os.environ["TABLE_NAME"]

db = boto3.client("dynamodb")


def get_user_name(user_id: int) -> str:
    response = db.get_item(
        TableName=TABLE_NAME,
        Key={"user_id": {"N": str(user_id)}},
    )
    user_name = response["Item"]["user_name"]["S"]
    return user_name


def send_to_slack(text: str, **kwargs) -> None:
    slack = WebClient(token=SLACK_TOKEN)
    res = slack.chat_postMessage(channel=SLACK_CHANNEL, text=text, **kwargs)
    if res.status_code != 200:
        raise Exception(f"Slack API returned status: {res.status_code}")


def handler(event, context):
    user_name = get_user_name(1)

    text = f"Lambda function is executed. Got user '{user_name}' from DynamoDB."
    send_to_slack(text, username="Lambda App")

    response = {"statusCode": 200, "body": text}
    return response


if __name__ == "__main__":
    print(handler({}, {}))
