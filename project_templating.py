from jinja2 import Template

class ProjectTemplating:
    def render(self, template_file, data, output_file = None):
        try:
            with open(template_file) as file:
                template = Template(file.read())
                output = template.render(dict(data))

                if output_file is not None:
                    with open(output_file, 'w') as target_file:
                        target_file.write(output)

            return output

        except Exception as e:
            print(e)
