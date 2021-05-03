import os
import pathlib

CONFIG_FILENAME = '.project'

class project_config:
    def ___init___(self, path):
        self.path = os.path.abspath(path)
        self.home_dir = str(pathlib.Path.home())

    def get_config_location(self):
        config_filename = False
        current_path = self.path
        while not config_filename:
            filename = os.path.join(current_path, CONFIG_FILENAME)
            if os.path.isfile(filename):
                config_filename = filename
                break
            else:
                current_path = pathlib.Path(current_path).resolve().parent
                if current_path is self.home_dir:
                    raise Exception('No configuration file found. Stopped at home dir.')

        return config_filename

