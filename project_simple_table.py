import click
import shutil
from functools import reduce

BORDER_HORIZONTAL = '─'
BORDER_VERTICAL = '│'
CORNER_TOP_LEFT = '┌'
CORNER_TOP_RIGHT = '┐'
CORNER_BOTTOM_LEFT = '└'
CORNER_BOTTOM_RIGHT = '┘'

T_RIGHT = '├'
T_LEFT = '┤'
T_BOTTOM = '┬'
T_TOP = '┴'

ELLIPSIS = '...'
DEFAULT_COLUMN_SETTINGS = {
    'styles': {},
}

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


    def print(self, data, column_settings=None, width='auto'):
        (terminal_width, terminal_height) = shutil.get_terminal_size()

        num_columns = len(data[0])
        columns = []
        for column_index in range(num_columns):
            min_width = 0
            for row in data:
                content = str(row[column_index])
                if len(content) > min_width:
                    min_width = len(content)



            column = DEFAULT_COLUMN_SETTINGS.copy()
            if column_index in column_settings:
                column.update(column_settings[column_index])
            column['original_width'] = min_width
            column['width'] = min_width
            columns.append(column)


        # Calculate column widths.
        all_widths = reduce(lambda result, c: result + c['width'], columns, 0)
        # Accomodate table borders.
        all_widths += len(columns) + 1

        if width == 'full':
            available_width_offset = 0
            width_offset_factor = 1

            available_width_offset = terminal_width - all_widths
            width_offset_factor = terminal_width / all_widths

            for column_index, column in enumerate(columns):
                # We need to expand or shrink this column.
                offset = available_width_offset / (len(columns) - column_index)
                new_width = round(column['width'] + offset)
                diff = new_width - column['width']
                available_width_offset -= diff
                column['width'] = new_width

            # Since the rounding of widths will probably lead to a difference
            # between the so far calculated column widths and the available_width_offset
            # let's adjust the last column to make the table use the width we
            # want it to.
            # A positive offset means that we need to expand the column.
            if available_width_offset is not 0:
                columns[-1]['width'] += available_width_offset
                available_width_offset = 0

        last_line = ''
        for row_index, row in enumerate(data):
            if row_index == 0:
                # Calculate the first and last lines.
                first_line = CORNER_TOP_LEFT
                last_line = CORNER_BOTTOM_LEFT
                for column_index, current_column in enumerate(row):
                    column_width = columns[column_index]['width']
                    first_line += ''.rjust(column_width, BORDER_HORIZONTAL)
                    last_line += ''.rjust(column_width, BORDER_HORIZONTAL)
                    if column_index < len(row):
                        first_line += T_BOTTOM
                        last_line += T_TOP

                first_line = first_line[:-1] + CORNER_TOP_RIGHT
                last_line =  last_line[:-1] + CORNER_BOTTOM_RIGHT

                click.echo(first_line)


            for column_index, current_column in enumerate(row):
                column_width = columns[column_index]['width']
                content = str(current_column)
                if len(content) <= column_width:
                    content = content.ljust(column_width, ' ')
                else:
                    length = column_width - len(ELLIPSIS)
                    content = content[0:length] + ELLIPSIS

                click.echo(BORDER_VERTICAL, nl=False)
                click.echo(content, nl=False)

            click.echo(BORDER_VERTICAL)

        click.echo(last_line)





