import json
import os

from slack_sdk import WebClient

SLACK_TOKEN = os.environ["SLACK_TOKEN"]
SLACK_CHANNEL = os.environ["SLACK_CHANNEL"]


def send_to_slack(text: str, **kwargs) -> None:
    slack = WebClient(token=SLACK_TOKEN)
    res = slack.chat_postMessage(channel=SLACK_CHANNEL, text=text, **kwargs)
    if res.status_code != 200:
        raise Exception(f"Slack API returned status: {res.status_code}")


def handler(event, context):
    message = json.loads(event["Records"][0]["Sns"]["Message"])
    timestamp = message["timestamp"]
    function_arn = message["requestContext"]["functionArn"]
    error_message = json.dumps(message["responsePayload"], indent=4)

    text = (
        f"Timestamp: {timestamp}\nFunction ARN: {function_arn}"
        f"\nError Message: {error_message}"
    )
    send_to_slack(text, username="Lambda Alert")

    response = {"statusCode": 200, "body": text}
    return response


if __name__ == "__main__":
    event = {
        "Records": [
            {
                "Sns": {
                    "Message": json.dumps(
                        {
                            "timestamp": "2021-09-01T00:00:00.000Z",
                            "requestContext": {
                                "functionArn": "arn:aws:lambda:us-east-1:123456789012:"
                                "function:sns-alert-dev-handler",
                            },
                            "responsePayload": {
                                "errorMessage": "An error occurred",
                            },
                        }
                    )
                }
            }
        ]
    }
    print(handler(event, {}))
