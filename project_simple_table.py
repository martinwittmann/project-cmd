import click

class SimpleTable:
    def __init__(self, left_width=10):
        self.left_width = left_width

    def print_table(self, data, left_color='white', right_color='white',
                    min_distance=1):
        for row in data:
            if len(row['left']) + min_distance > self.left_width:
                self.left_width = len(row['left']) + min_distance

        for row in data:
            click.secho(row['left'].ljust(self.left_width, ' '), fg=left_color, nl=False)
            click.secho(row['right'], fg=right_color)
