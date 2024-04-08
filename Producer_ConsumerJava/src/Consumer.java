import java.util.Random;
import java.util.Stack;
import java.util.concurrent.Semaphore;
class Consumer implements Runnable {
    private Semaphore full;
    private Semaphore empty;
    private Semaphore access;
    private Stack<String> storage;
    private int consumerIndex;

    public Consumer(Semaphore full, Semaphore empty, Semaphore access, Stack<String> storage, int consumerIndex) {
        this.full = full;
        this.empty = empty;
        this.access = access;
        this.storage = storage;
        this.consumerIndex = consumerIndex;
    }

    public void run() {
        try {
            for (int i = 0; i < 10; i++) {
                full.acquire(); // Wait until there's an item in the storage
                access.acquire(); // Acquire access to the storage

                String item = storage.pop();
                System.out.println("Consumer [" + consumerIndex + "] take " + item);

                access.release(); // Release access to the storage
                empty.release(); // Signal that an item has been consumed
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}