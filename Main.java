public class Main {
    public static int a;

    public static void main(String[] args) {
        System.out.println("Hello! " + 42);
        System.out.println(42);

        a = 42;
        a = a + 90;
        a = a - 30;
        //a = a * 2;
        System.out.println(a);
    }
}