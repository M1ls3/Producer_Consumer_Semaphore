import java.util.Random;
import java.util.Stack;
import java.util.concurrent.Semaphore;
class Producer implements Runnable {
    private Semaphore full;
    private Semaphore empty;
    private Semaphore access;
    private Stack<String> storage;
    private int producerIndex;

    public Producer(Semaphore full, Semaphore empty, Semaphore access, Stack<String> storage, int producerIndex) {
    this.full = full;
    this.empty = empty;
    this.access = access;
    this.storage = storage;
    this.producerIndex = producerIndex;
}

public void run() {
    try {
        for (int i = 0; i < 10; i++) {
            empty.acquire(); // Wait until there's space in the storage
            access.acquire(); // Acquire access to the storage

            storage.push(Production.work());
            System.out.println("Producer [" + producerIndex + "] produced " + storage.peek());

            access.release(); // Release access to the storage
            full.release(); // Signal that an item has been produced
        }
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
}
}