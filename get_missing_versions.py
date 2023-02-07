import json
import os.path
import sys

import requests as requests


def make_get(url) -> dict:
    response = requests.get(url)
    if response.status_code != 200:
        sys.exit(f"URL {url} returned code {response.status_code}")
    return json.loads(response.text)


def get_git_tags():
    url = "https://git.cloudron.io/api/v4/projects/15/repository/tags"
    response = make_get(url)

    tags = []
    for item in response:
        tag = item['name'].replace("v", "")
        tags.append(tag)

    return tags


def get_docker_tags():
    url = "https://hub.docker.com/v2/repositories/rossmaclean/cloudron-base-image/tags?page_size=1024"
    response = make_get(url)

    tags = []
    for item in response["results"]:
        tags.append(item["name"])

    return tags


def get_missing_tags():
    git_tags = get_git_tags()
    print(f"Got git tags {git_tags}")

    docker_tags = get_docker_tags()
    print(f"Got docker tags {docker_tags}")

    diff = list(set(git_tags) - set(docker_tags))
    diff.sort()
    print(f"Tags missing from docker {diff}")

    return diff


if __name__ == '__main__':
    missing_tags = get_missing_tags()
    with open(os.environ["GITHUB_ENV"], "w") as text_file:
        text_file.write(f"missing_tags={missing_tags}")
