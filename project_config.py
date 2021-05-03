import click
import os
import pathlib

CONFIG_FILENAME = '.project'

class ProjectConfig:
    def __init__(self, verbose=0):
        self.path = os.getcwd()
        self.verbose = verbose
        self.home_dir = str(pathlib.Path.home())

    def get_config_location(self):
        config_filename = False
        current_path = self.path
        if self.verbose > 0:
            click.echo('Searching project config...')

        while not config_filename:
            filename = os.path.join(current_path, CONFIG_FILENAME)
            if self.verbose > 1:
                click.echo('Searching project config at {}'.format(filename))
            if os.path.isfile(filename):
                config_filename = filename
                break
            else:
                current_path = str(pathlib.Path(current_path).resolve().parent)
                if self.is_root(current_path) or self.is_home_dir(current_path):
                    raise Exception('No configuration file found. Stopped at {}.'
                                    .format(current_path))

        if self.verbose > 0:
            click.echo('Found project config at {}'.format(config_filename))
        return config_filename


    def is_home_dir(self, path):
        return path is self.home_dir

    def is_root(self, path):
        return os.path.dirname(path) == path
