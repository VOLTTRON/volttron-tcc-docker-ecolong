import json


def create_json_file(value):

    # Data to be written
    dictionary = {
      "data":
            [
                    {"value": value 
                    }
            ]
    }

    # Serializing json
    json_object = json.dumps(dictionary, indent=4)

    # Writing to sample.json
    with open("data.json", "w") as outfile:
        outfile.write(json_object)
        print("Created data.json")


def load_json(file_name):

    # Opening JSON file
    f = open(file_name)

    # returns JSON object as
    # a dictionary
    data = json.load(f)

    # Iterating through the json
    # list
    # for i in data['emp_details']:
    #     print(i)

    print(data)

    # Closing file
    f.close()

    return data


def select_payload(payload_type):

    file_name = payload_type + ".json"

    payload = load_json(file_name)

    return payload


# create_json_file(11)
