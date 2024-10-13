import os, requests

import google.auth
from google.auth.transport.requests import Request
from google.cloud import resourcemanager_v3

ORGANIZATION_ID = os.getenv('ORGANIZATION_ID')
RESTRICTIONS = os.getenv('RESTRICTIONS')
ORIGIN = os.getenv('ORIGIN')
REASON = os.getenv('REASON')

def list_projects_and_folders(folder_client, project_client, parent):
    projects = []
    request = resourcemanager_v3.ListProjectsRequest(parent=parent)
    for project in project_client.list_projects(request=request):
        projects.append(project.project_id)
    folders = folder_client.list_folders(parent=parent)
    for folder in folders:
        projects.extend(list_projects_and_folders(folder_client, project_client, folder.name))
    return projects

def list_all_projects_in_org(org_id):
    folder_client = resourcemanager_v3.FoldersClient()
    project_client = resourcemanager_v3.ProjectsClient()
    org_parent = f"organizations/{org_id}"
    return list_projects_and_folders(folder_client, project_client, org_parent)

def get_access_token():
    credentials, _ = google.auth.default()
    credentials.refresh(Request())
    return credentials.token

def get_liens(token, project_id):
    url = f'https://cloudresourcemanager.googleapis.com/v3/liens?parent=projects/{project_id}'
    headers = {
        'Authorization': f'Bearer {token}'
    }
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        else:
            False
    except Exception as e:
        print(e)
    
def add_lien(token, project_id):
    data = {
        "origin": ORIGIN,
        "parent": f"projects/{project_id}",
        "reason": REASON,
        "restrictions": [RESTRICTIONS],
    }
    url = f'https://cloudresourcemanager.googleapis.com/v3/liens'
    headers = {
        'Authorization': f'Bearer {token}'
    }
    try:
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            return True
        else:
            return False
    except Exception as e:
        print(e)

def lien_manager(credentials, projects):
    for project in projects:
        rules = get_liens(credentials, project)
        if rules:
            restrictions = [restriction for project_liens in rules['liens'] for restriction in project_liens['restrictions']]
            if RESTRICTIONS not in restrictions:
                status = add_lien(credentials, project)
                if status != True:
                    print(f"[!] Error adding lien to project: {project}, check permissions [!]")
                else:
                    print(f"[+] Lien successfully added to project: {project} [+]")
            else:
                print(f"[~] Project {project} already has project deletion lien. [~]")
        else:
            status = add_lien(credentials, project)
            if status != True:
                print(f"[!] Error adding lien to project: {project} [!]")
            else:
                print(f"[+] Lien successfully added to project: {project} [+]")

def main(event, context):

    projects = list_all_projects_in_org(ORGANIZATION_ID)
    if projects:
        print(f"{len(projects)} projects found in the organization.")
        token = get_access_token()
        lien_manager(token, projects)
    else:
        print("[!] No projects found. [!]")

if __name__ == "__main__":
    
    main(event=None, context=None)