from setuptools import setup, find_packages

setup(
    name='project',
    version='0.1',
    python_requires='>=3',
    packages=find_packages(),
    install_requires=[
        'Click',
        'click_completion',
        'PyYAML',
        'python-dotenv',
        'python_hosts',
        'fabric',
        'jinja2',
    ],
    entry_points={
        'console_scripts': [
            'project = project:main',
        ],
    },
)
