import java.util.Random;
import java.util.Stack;
import java.util.concurrent.Semaphore;

public class Main {
    public static void main(String[] args) {
        int producerAmount = 1;
        int consumerAmount = 1;
        Semaphore full = new Semaphore(0);
        Semaphore empty = new Semaphore(10);
        Semaphore access = new Semaphore(1);
        Stack<String> storage = new Stack<>();

        Thread[] producerThreads = new Thread[producerAmount];
        Thread[] consumerThreads = new Thread[consumerAmount];

        for (int i = 0; i < producerAmount; i++) {
            producerThreads[i] = new Thread(new Producer(full, empty, access, storage, i));
            producerThreads[i].start();
        }

        for (int i = 0; i < consumerAmount; i++) {
            consumerThreads[i] = new Thread(new Consumer(full, empty, access, storage, i));
            consumerThreads[i].start();
        }

        try {
            for (Thread producerThread : producerThreads) {
                producerThread.join();
            }

            for (Thread consumerThread : consumerThreads) {
                consumerThread.join();
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        System.out.println("All items produced and consumed.");
    }
}