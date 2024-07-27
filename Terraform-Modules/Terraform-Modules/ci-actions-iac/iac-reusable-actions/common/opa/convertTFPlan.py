import json
import random
import os

def convert_configuration(config):
  '''
  Flattens the Json module configuration so that every module is on the first level.
  Typically the configuration includes modules, submodules and subsubmodules. 
  We don't really care what their parents are so we put them all on the first level to
  make it easier to process in OPA.

  @config - a dictionary of config elements from the terraform plan
  '''
  first_level = config["root_module"]["module_calls"]
  for key in first_level.keys():
    first_level[key]["parent_modules"] = []
  main_level = config["root_module"]
  new_module_calls = []
  level_queue = []
  level_queue.append(first_level)
  while len(level_queue) > 0:
    cur_level = level_queue.pop()
    for key in cur_level.keys():
      if "module_calls" in cur_level[key]["module"].keys():
        t_level = cur_level[key]["module"]["module_calls"].copy()
        for t_key in cur_level[key]["module"]["module_calls"].keys():
          rand_key = f'{t_key}{random.randint(0,100000)}'
          t_level[rand_key] = t_level.pop(t_key)
          t_level[rand_key]["parent_modules"] = cur_level[key]["parent_modules"].copy()
          t_level[rand_key]["parent_modules"].append(cur_level[key]["source"])

        new_module_calls.append(t_level)   
        level_queue.append(cur_level[key]["module"]["module_calls"])
  for call in new_module_calls:
    main_level["module_calls"].update(call)
  return main_level

def main():
  json_file = os.environ["JSON_FILE"]
  with open(json_file) as f: 
    data = json.load(f)

  config = data["configuration"]
  data["configuration"]["root_module"] = convert_configuration(config)
  print("Converted configuration")
  with open(json_file, 'w') as f:
    json.dump(data, f)
  

main()
