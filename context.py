import project_config
import project_hosts
import project_simple_table
import project_database
import project_ssh
import project_archives

def init(ctx):
    ctx.ensure_object(dict)
    ctx.obj['verbosity'] = 0

    if not 'config' in ctx.obj:
        ctx.obj['config'] = project_config.ProjectConfig(ctx.obj['verbosity'])

    if not 'hosts' in ctx.obj:
        ctx.obj['hosts'] = project_hosts.Hosts()

    if not 'simple_table' in ctx.obj:
        ctx.obj['simple_table'] = project_simple_table.SimpleTable()

    if not 'db' in ctx.obj:
        ctx.obj['db'] = project_database.Database(ctx.obj['config'])

    if not 'ssh' in ctx.obj:
        ctx.obj['ssh'] = project_ssh.ProjectSsh(ctx.obj['config'])

    if not 'archives' in ctx.obj:
        ctx.obj['archives'] = project_archives.Archives(ctx.obj['config'])

def init_project(ctx, project=None):
    ctx.obj['config'].init_project_data(project)


