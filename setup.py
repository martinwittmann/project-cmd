from setuptools import setup

setup(
    name='project-cmd',
    version='0.1',
    py_modules=['project_cmd'],
    install_requires=[
        'Click',
        'click_completion',
        'PyYAML',
        'python-dotenv',
        'paramiko',
    ],
    entry_points='''
        [console_scripts]
        project=project_cmd:main
    ''',
)