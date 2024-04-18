import java.util.Random;
import java.util.Stack;
import java.util.concurrent.Semaphore;
class  Production {
    public static Random rand = new Random();
    public static boolean isDone = false;
    public static int maxProduced = 0;
    public static int produced = 0;

    public static String work() {
        return "item [" + rand.nextInt(101) + "]";
    }

    public static boolean Check()
    {
        isDone = maxProduced <= produced;
        return isDone;
    }
}