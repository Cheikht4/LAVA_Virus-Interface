import re
import os
import sys

def get_perl_params(script_path):
    params = set()
    with open(script_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    matches = re.findall(r'"([a-zA-Z0-9_\|]+)=?[sfi]?"\s*=>', content)
    for match in matches:
        for param in match.split('|'):
            params.add(param)
    return params

def get_flask_params():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    try:
        import lava_flask_app
        common = set(lava_flask_app.common_params)
        loop = set(lava_flask_app.loop_only_params)
        stem = set(lava_flask_app.stem_only_params)
        print("IMPORTED SUCCESSFULLY")
        return common, loop, stem
    except Exception as e:
        print("FAILED TO IMPORT", e)
        sys.exit(1)

def main():
    common, loop, stem = get_flask_params()
    flask_loop_params = common.union(loop)
    flask_stem_params = common.union(stem)
    
    print("Loop params from Flask:", len(flask_loop_params))
    
    # Check if there are stem params that made it into common or loop
    for p in stem:
        if p in flask_loop_params:
            print(f"WARNING: Stem param {p} is in flask_loop_params!")

    dna_public_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'lava-dna-public')
    loop_perl = os.path.join(dna_public_dir, 'lava_loop_primer.pl')
    
    perl_loop_params = get_perl_params(loop_perl)
    print("Loop params from Perl:", len(perl_loop_params))
    
    for param in flask_loop_params:
        if param not in perl_loop_params and param not in ('fixed_primers', 'lamp_mode', 'script_type', 'threads', 'cpu'):
            print(f"[ERREUR] Paramètre LOOP envoyé par l'interface mais inconnu du script Perl: {param}")

if __name__ == '__main__':
    main()
