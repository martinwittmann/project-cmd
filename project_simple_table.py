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
T_ALL = '┼'

ELLIPSIS = '...'
DEFAULT_COLUMN_SETTINGS = {
    'styles': {},

    # Possible values: 'left', 'right', 'center',
    'align': 'left',
}

class SimpleTable:

    def print(self, data, column_settings=[], width='auto', border_styles={}, show_horizontal_lines=True, show_vertical_lines=True, headers=[]):
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
            if column_index < len(column_settings):
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
            if available_width_offset != 0:
                columns[-1]['width'] += available_width_offset
                available_width_offset = 0

        last_line = ''
        for row_index, row in enumerate(data):
            if row_index == 0:
                # Calculate the first and last lines.
                first_line = CORNER_TOP_LEFT
                between_line = T_RIGHT
                last_line = CORNER_BOTTOM_LEFT
                header_line = ''
                after_header_line = ''

                show_header = len(headers) == len(columns)

                for column_index, current_column in enumerate(row):
                    column_width = columns[column_index]['width']
                    first_line += ''.rjust(column_width, BORDER_HORIZONTAL)
                    between_line += ''.rjust(column_width, BORDER_HORIZONTAL)
                    last_line += ''.rjust(column_width, BORDER_HORIZONTAL)

                    if show_header:
                        header_content = headers[column_index]
                        header_line += click.style(BORDER_VERTICAL, **border_styles)
                        header_line += click.style(header_content.ljust(column_width, ' '), bold=True)
                    after_header_line += ''.rjust(column_width, BORDER_HORIZONTAL) + T_ALL
                    if column_index < len(row):
                        if show_vertical_lines:
                            first_line += T_BOTTOM
                            between_line += T_ALL
                            last_line += T_TOP
                        else:
                            first_line += BORDER_HORIZONTAL
                            between_line += BORDER_HORIZONTAL
                            last_line += BORDER_HORIZONTAL

                first_line = first_line[:-1] + CORNER_TOP_RIGHT
                between_line = between_line[:-1] + T_LEFT
                last_line = last_line[:-1] + CORNER_BOTTOM_RIGHT
                header_line = header_line + click.style(BORDER_VERTICAL, **border_styles)
                after_header_line = between_line[:-1] + T_LEFT

                click.secho(first_line, **border_styles)
                if show_header:
                    click.echo(header_line)
                    click.secho(after_header_line, **border_styles)

            for column_index, current_column in enumerate(row):
                column_settings = columns[column_index]
                column_width = column_settings['width']
                content = str(current_column)
                if len(content) <= column_width:
                    if column_settings['align'] == 'right':
                        content = content.rjust(column_width, ' ')
                    elif column_settings['align'] == 'center':
                        left_pad_width = round((column_width - len(content)) / 2)
                        content = content.ljust(len(content) + left_pad_width, ' ')
                        content = content.rjust(column_width, ' ')
                    else:
                        content = content.ljust(column_width, ' ')
                else:
                    length = column_width - len(ELLIPSIS)
                    content = content[0:length] + ELLIPSIS

                if column_index == 0 or show_vertical_lines:
                    click.secho(BORDER_VERTICAL, **border_styles, nl=False)
                else:
                    click.secho(' ', **border_styles, nl=False)

                click.echo(content, nl=False)

            click.secho(BORDER_VERTICAL, **border_styles)
            if row_index < len(data) - 1 and show_horizontal_lines:
                click.secho(between_line, **border_styles)

        click.secho(last_line, **border_styles)





