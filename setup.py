from setuptools import setup

setup(
    name='project-cmd',
    version='0.1',
    py_modules=[
        'project_cmd',
        'project_config',
        'project_database',
        'project_hosts',
        'project_simple_table',
        'project_util',
    ],
    install_requires=[
        'Click',
        'click_completion',
        'PyYAML',
        'python-dotenv',
        'fabric',
        'python_hosts',
    ],
    entry_points='''
        [console_scripts]
        project=project_cmd:main
    ''',
)
