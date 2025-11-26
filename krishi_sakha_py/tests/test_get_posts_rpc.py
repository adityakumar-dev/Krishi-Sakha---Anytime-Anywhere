import sys, os
sys.path.insert(0, os.getcwd())
from configs.supabase_key import SUPABASE

def test_get_posts():
    try:
        result = SUPABASE.rpc('get_posts', {
            'place_arg': None,
            'type_arg': None,
            'status_arg': None,
            'limit_arg': 5,
            'offset_arg': 0
        }).execute()
        print('✅ RPC works! Posts:', len(result.data))
        print('Data:', result.data)
    except Exception as e:
        print('❌ Error:', e)

if __name__ == "__main__":
    test_get_posts()
