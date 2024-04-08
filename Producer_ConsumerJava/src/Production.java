import java.util.Random;
import java.util.Stack;
import java.util.concurrent.Semaphore;
class Production {
    public static Random rand = new Random();

    public static String work() {
        return "item [" + rand.nextInt(101) + "]";
    }
}