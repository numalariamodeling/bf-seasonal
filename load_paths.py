import os


def load_box_paths(user_path=None, parser_default='HPC'):

    if not user_path :
        user_path = os.path.expanduser('~')
        if 'jlg1657' in user_path :
            user_path = 'E:/'
        if 'cygwin' in user_path :
            netid = os.path.split(user_path)[1]
            user_path = os.path.join('C:/Users/', netid)
        if 'mrung' in user_path :
            user_path = 'C:/Users/mrung'
    if 'mambrose' in os.path.expanduser('~'):
        user_path = os.path.expanduser('~')
        home_path = os.path.join(user_path, 'Box')
        data_path = home_path
        project_path = os.path.join(home_path, 'hbhi_burkina')
    elif parser_default == 'HPC':
        home_path = os.path.join(user_path, 'Box', 'NU-malaria-team')
        data_path = os.path.join(home_path, 'data')
        project_path = os.path.join(home_path, 'projects', 'hbhi_burkina')
    else:
        project_path = '/projects/b1139/bf-seasonal/IO'
        data_path = os.path.join(project_path, 'data')

    return data_path, project_path


def load_dropbox_paths(user_path=None):

    if not user_path :
        user_path = os.path.expanduser('~')
        if 'jlg1657' in user_path :
            user_path = 'E:/'

    home_path = os.path.join(user_path, 'Dropbox (IDM)', 'Malaria Team Folder')
    data_path = os.path.join(home_path, 'data')
    project_path = os.path.join(home_path, 'projects')

    return data_path, project_path
