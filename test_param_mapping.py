import re
import os
import sys

def get_perl_params(script_path):
    params = set()
    with open(script_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Simple regex to extract keys from %optionMap
    # Assuming lines like "alignment_fasta=s" => \$options{"alignment_fasta"},
    matches = re.findall(r'"([a-zA-Z0-9_\|]+)=?[sfi]?"\s*=>', content)
    for match in matches:
        # Handle aliases like "threads|cpu"
        for param in match.split('|'):
            params.add(param)
    return params

def get_flask_params():
    try:
        import lava_flask_app
        common = set(lava_flask_app.common_params)
        loop = set(lava_flask_app.loop_only_params)
        stem = set(lava_flask_app.stem_only_params)
        return common, loop, stem
    except Exception as e:
        print(f"Error importing lava_flask_app: {e}")
        # Fallback: simple text parsing of lava_flask_app.py
        common = set()
        loop = set()
        stem = set()
        with open('lava_flask_app.py', 'r', encoding='utf-8') as f:
            content = f.read()
        
        # very simple extraction, relies on the sets defined in the file
        for name in ['common_params', 'loop_only_params', 'stem_only_params']:
            match = re.search(f"{name}\s*=\s*{{(.*?)}}", content, re.DOTALL)
            if match:
                items = re.findall(r"'([^']+)'", match.group(1))
                if name == 'common_params':
                    common.update(items)
                elif name == 'loop_only_params':
                    loop.update(items)
                elif name == 'stem_only_params':
                    stem.update(items)
        return common, loop, stem

def main():
    common, loop, stem = get_flask_params()
    flask_loop_params = common.union(loop)
    flask_stem_params = common.union(stem)

    # Path to perl scripts
    dna_public_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'lava-dna-public')
    loop_perl = os.path.join(dna_public_dir, 'lava_loop_primer.pl')
    stem_perl = os.path.join(dna_public_dir, 'lava_stem_primer.pl')
    
    if not os.path.exists(loop_perl) or not os.path.exists(stem_perl):
        print(f"Cannot find Perl scripts in {dna_public_dir}")
        sys.exit(1)

    perl_loop_params = get_perl_params(loop_perl)
    perl_stem_params = get_perl_params(stem_perl)
    
    errors = 0
    print("=== AUDIT DES PARAMÈTRES ===")
    
    # Check LOOP
    for param in flask_loop_params:
        if param not in perl_loop_params and param not in ('fixed_primers', 'lamp_mode', 'script_type', 'threads', 'cpu'):
            print(f"[ERREUR] Paramètre LOOP envoyé par l'interface mais inconnu du script Perl: {param}")
            errors += 1
            
    # Check STEM
    for param in flask_stem_params:
        if param not in perl_stem_params and param not in ('fixed_primers', 'lamp_mode', 'script_type', 'threads', 'cpu'):
            print(f"[ERREUR] Paramètre STEM envoyé par l'interface mais inconnu du script Perl: {param}")
            errors += 1
            
    if errors > 0:
        print(f"\nÉCHEC: {errors} incohérence(s) trouvée(s).")
        sys.exit(1)
    else:
        print("\nSUCCÈS: Tous les paramètres envoyés par l'interface sont reconnus par les scripts Perl.")
        sys.exit(0)

if __name__ == '__main__':
    main()
