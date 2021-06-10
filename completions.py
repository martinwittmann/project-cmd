from context import init_context

def get_local_dumps(ctx, args, incomplete):
    init_context(ctx)
    ctx.obj['config'].setup_project()
    dumps = ctx.obj['db'].get_local_dumps(incomplete + '*')
    return dumps

def get_remote_dumps(ctx, args, incomplete):
    init_context(ctx)
    ctx.obj['config'].setup_project()
    project_id = ctx.obj['config'].get('id')
    dumps = ctx.obj['ssh'].get_dumps(project_id, incomplete + '*')
    return dumps

def project_names(ctx, args, incomplete):
    init_context(ctx)
    projects = ctx.obj['config'].get_all_projects()
    return [p['id'] for p in projects if p['id'].startswith(incomplete)]

def get_local_archives(ctx, args, incomplete):
    init_context(ctx)
    ctx.obj['config'].setup_project()
    archives = ctx.obj['archives'].get_local_archives(incomplete + '*')
    return archives
