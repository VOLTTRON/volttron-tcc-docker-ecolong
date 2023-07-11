# Communication Interface in FireFly

import requests
# from utils import select_payload


def ff_post(payload,
           protocol = 'http',
           ip = '127.0.0.1',
           port = '5100',
           msg_dir = "/api/v1/namespaces/default/messages/",
           comm_type = "broadcast"):

    server_location = protocol + '://' + ip + ':' + port
    print(server_location)

    url = server_location + msg_dir + comm_type
    print("url: ", url)

    response = requests.post(url, json = payload)

    return response


def ff_upload_blob(file_content,
                   protocol = 'http',
                   ip = '127.0.0.1',
                   port = '5100',
	           file = "/api/v1/namespaces/default/data"):

    server_location = protocol + '://' + ip + ':' + port
    # print(server_location)
    url = server_location + file
    print("url: ", url)

    response_post = requests.post(url, files={'file': file_content.read()})
	# print(type(response))

	# Need to broadcast the "id" so that other nodes can fetch the file
    blob_id = response_post.json()['id']

    return blob_id


def ff_get(protocol = 'http',
           ip = '127.0.0.1',
           port = '5100',
           msg_dir = "/api/v1/namespaces/default/datatypes",
           lookup_var = ""):

    server_location = protocol + '://' + ip + ':' + port
    # print(server_location)

    url = server_location + msg_dir + lookup_var
    print("url: ", url)

    response = requests.get(url)

    return response
