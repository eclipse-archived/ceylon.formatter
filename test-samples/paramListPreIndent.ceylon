shared class IdentityMap<Key, Item>
        (hashtable = HashTable(), entries = {})
        satisfies {<Key->Item>*} &
                Collection<Key->Item> &
                Correspondence<Key,Item>
        given Key satisfies Identifiable
        given Item satisfies Object {
}
