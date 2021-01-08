import httpx
from asyncio import run
from typing import List
import dataclasses

url = "http://internal-int-load-balancer-222146539.us-east-1.elb.amazonaws.com/demo"
url_fargate = "http://internal-int-load-balancer-222146539.us-east-1.elb.amazonaws.com/fargate"
api_gateway_url = "https://kngoeirt00.execute-api.us-east-1.amazonaws.com/dev"

def get_chart(results):
    from quickchart import QuickChart

    qc = QuickChart()
    qc.width = 900
    qc.height = 500
    qc.device_pixel_ratio = 2.0
    qc.config = {
        "type": "line",
        "data": {
            "labels": list(range(len(results))),
            "datasets": [
                {
                    "label": "ms",
                    "backgroundColor": "rgb(255, 99, 132)",
                    "borderColor": "rgb(255, 99, 132)",
                    "data": results,
                    "fill": False,
                },
            ],
        },
    }

    return qc.get_url()

@dataclasses.dataclass
class RunResult:
    name: str
    first_response: httpx.Response
    results: List[float]

async def bench(name, url, headers=None):
    from datetime import datetime

    durations = []

    async with httpx.AsyncClient(headers={
        'user-agent': 'my-app/0.0.1',
        **(headers or {})
    }) as client:
        r = await client.get(url)

        for i in range(100):
            start = datetime.now()
            await client.get(url)
            end = datetime.now()

            durations.append((end - start).total_seconds() * 1000)

    return RunResult(name, r, durations)


async def run_benchmarks():
    all_results = []

    all_results.append(await bench("API Gateway + Lambda", api_gateway_url, {'x-apigw-api-id': 'kngoeirt00'}))
    all_results.append(await bench("ALB + Lambda", url))
    all_results.append(await bench("ALB + Fargate", url_fargate))

    return all_results


def handler(event, context):
    ua = (event['headers'] or {}).get('user-agent', '')

    print(ua)
    body = ''

    if 'Mozilla' in ua:
        all_results = run(run_benchmarks())

        for result in all_results:
            body += f'''
            <h1>{result.name}</h1>
            <div>{result.first_response.http_version}</div>
            <div>{result.first_response.status_code}</div>
            <img width="600" src="{get_chart(result.results)}">
            '''

    return {
      "statusCode": 200,
      "body": body,
      "headers": {
        "Content-Type": "text/html"
      }
    }
