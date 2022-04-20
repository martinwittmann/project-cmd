import click
import os
import yaml
import subprocess

import util
from util import project_cmd_show_click_exception, debug
from dotenv import dotenv_values
import project_config

DOCKER_DIR = 'docker'
DOCKER_COMPOSE = 'docker-compose.yml'

class Docker:

    def __init__(self, config):
        self.config = config

    def get_docker_compose_filename(self, project_id=None):
        if project_id is None:
            dot_project_dir = self.config.dot_project_dir
        else:
            ext_config = project_config.ProjectConfig()
            ext_config.init_project_data(project_id)
            dot_project_dir = ext_config.dot_project_dir

        return os.path.join(dot_project_dir,
                            DOCKER_DIR, DOCKER_COMPOSE)

    def get_dependencies(self):
        #Extract the list of project dependencies from docker-compose.
        return self.config.get('dependencies')

    def start_with_docker_compose(self):
        dependencies = self.get_dependencies()
        dependencies.insert(0, self.config.config_file)
        env_file = self.config.env_file
        command = [
            'docker-compose',
            '--env-file',
            env_file,
        ]

        for dependency in dependencies:
            command.append('-f')
            command.append(self.get_docker_compose_filename(dependency))

        command.append('up')
        command.append('-d')

        if self.config.has_key('docker_compose_services'):
            for service in self.config.get('docker_compose_services'):
                command.append(service)

        print(command)
        subprocess.run(command)

