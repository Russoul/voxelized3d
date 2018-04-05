module arraylist;


//TODO REMOVE ME, USE std.container.array instead
public class ArrayList(V) {
    V[] array;
    private int lastIndex;

    /**
        * Constructs an ArrayList with the default starting size,
        * which is currently 10.
        */
    public this() {
        this(10);
    }

    /**
        * Constructs an ArrayList with the specified starting size
        * Params:
        *     size = the starting size
        */
    public this(uint size) {
        array = new V[size];
        lastIndex = -1;
    }
    
    private this(V[] arr, uint lastIndex) {
        array = arr;
        this.lastIndex = lastIndex;
    }

    /**
        * Adds an item to the end of the ArrayList
        * Params:
        *     item = the item to add to the ArrayList
        * Returns: a reference to the ArrayList
        */
    public ArrayList!(V) push(V item) {
        if(lastIndex == array.length - 1) {
            grow();
        }
        array[++lastIndex] = item;
        return this;
    }

    private void grow() {
        array.length = array.length * 2;
    }

    /**
        * Returns the number of elements in the ArrayList
        */
    size_t size() {
        return lastIndex + 1;
    }
    
    /**
        * Returns the current length of the ArrayList
        * if this size is exceeded, the ArrayList will grow
        */
    size_t capacity() {
        return array.length;
    }

    /**
        * Returns true if the ArrayList is empty
        */
    bool isEmpty() {
        return lastIndex == -1;
    }

    /**
        * Returns a shallow copy of the ArrayList
        */
    ArrayList!(V) dup() {
        return new ArrayList!(V)(array.dup, lastIndex);
    }

    /**
        * Removes all elements from the ArrayList
        * Returns a reference to the ArrayList
        */
    ArrayList!(V) clear() {
        for(int i = 0; i <= lastIndex; i++) {
            //I don't see what I would do here with nonobjects...
            array[i] = V.init;
        }
        return this;
    }

    /**
        * Returns true if the ArrayList contains the specified value
        */
    bool contains(V value) {
        for(int i = 0; i <= lastIndex; i++) {
            if(array[i] == value)
                return true;
        }

        return false;
    }


    V opIndex(uint i) {
        return array[i];
    }

    V opIndexAssign(V item, uint i) {
        return item;
    }

    alias opIndex get;
    alias opIndexAssign set; //this may be somewhat conterintuitive as set(index, item) feels more natural?
}
