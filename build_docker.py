#!/usr/bin/env python3
import datetime
import os
import subprocess
import logging
import argparse

today_tag = datetime.datetime.now().strftime("%d%m%Y")

# Creating argparse parser
parser = argparse.ArgumentParser(description="Build Dockerfile")
parser.add_argument('docker', type=str, help='Name of the Dockerfile to build - should match a folder name in this repo')
parser.add_argument('--username', type=str, default="f00d4tehg0dz", help=f"Docker Hub username. Defaults to: f00d4tehg0dz")
parser.add_argument('--tag', type=str, default=today_tag, help=f"Tag to use. Defaults to today's date: {today_tag}")
parser.add_argument('--latest', action="store_true", help='If specified, we will also tag and push :latest')
parser.add_argument('--no-push', action="store_true", help='Build only, do not push to Docker Hub')
args = parser.parse_args()

logger = logging.getLogger()
logging.basicConfig(
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s", level=logging.INFO, datefmt="%Y-%m-%d %H:%M:%S"
)

dockerLLM_dir = os.path.dirname(os.path.realpath(__file__))
username = args.username

def docker_command(command):
    try:
        logger.info(f"Running docker command: {command}")
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError as e:
        logger.error(f"Got error while executing docker command: {e}")
        raise
    except Exception as e:
        raise e

def build(docker_repo, tag, push=True):
    docker_container = f"{username}/{docker_repo}:{tag}"
    logger.info(f"Building {docker_container}")

    # Build arguments
    docker_build_arg = f"--progress=plain -t {docker_container}"

    # Use repo root as context, specify Dockerfile path with -f
    # This allows access to workflows/ folder from root
    dockerfile_path = f"{dockerLLM_dir}/{docker_repo}/Dockerfile"
    build_command = f"docker build {docker_build_arg} -f {dockerfile_path} {dockerLLM_dir}"

    docker_command(build_command)

    if push:
        push_command = f"docker push {docker_container}"
        docker_command(push_command)
        logger.info(f"Successfully pushed {docker_container}")
    else:
        logger.info(f"Build complete. Skipping push (--no-push specified)")

    return docker_container

def tag(source_container, target_container, push=True):
    tag_command = f"docker tag {source_container} {target_container}"
    docker_command(tag_command)
    if push:
        docker_command(f"docker push {target_container}")


try:
    container = build(
        args.docker,
        args.tag,
        push=not args.no_push
    )
    logger.info(f"Successfully built the container: {container}")

    if args.latest:
        latest = f"{username}/{args.docker}:latest"
        tag(container, latest, push=not args.no_push)
        if not args.no_push:
            logger.info(f"Successfully tagged and pushed to {latest}")
        else:
            logger.info(f"Successfully tagged as {latest}")

except subprocess.CalledProcessError as e:
    logger.error(f"Process aborted due to error running Docker commands")
except Exception as e:
    raise e