from setuptools import setup

setup(
    name='project-cmd',
    version='0.1',
    py_modules=['project_cmd'],
    install_requires=[
        'Click',
    ],
    entry_points='''
        [console_scripts]
        project_cmd=project_cmd:main
    ''',
)