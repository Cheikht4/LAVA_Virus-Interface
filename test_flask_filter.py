import json
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lava_flask_app import common_params, loop_only_params, stem_only_params, param_mapping

def build_cmd(params, script_type):
    valid_perl_params = common_params.copy()
    if script_type.upper() == 'LOOP':
        valid_perl_params.update(loop_only_params)
    elif script_type.upper() == 'STEM':
        valid_perl_params.update(stem_only_params)
        
    cmd = []
    for param_name, param_value in params.items():
        if param_value is not None and param_name not in ['script_type', 'lamp_mode', 'fixed_primers']:
            perl_param_name = param_mapping.get(param_name, param_name)
            if perl_param_name in valid_perl_params:
                cmd.extend([f"--{perl_param_name}", str(param_value)])
            else:
                print(f"Python a IGNORE et n a pas passe a perl le parametre: {param_name} -> {perl_param_name}")
    return cmd

params = {
    "stem_primer_target_length": 20,
    "include_stem_primers": 1,
    "loop_min_gap": 5,
    "signature_max_length": 300
}

print("Commande construite pour LOOP:")
cmd = build_cmd(params, "LOOP")
print(cmd)
