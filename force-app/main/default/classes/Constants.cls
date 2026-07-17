public class Constants {

    // Business Rules
    public static final String HIGH_PRIORITY = 'High Priority';
    public static final Integer OPPORTUNITY_AGE_LIMIT = 45;

    // Score Rules
    public static final Integer BASE_SCORE = 50;
    public static final Integer HIGH_PRIORITY_BONUS = 30;
    public static final Integer OLD_OPPORTUNITY_PENALTY = 10;
    public static final Integer NO_OLD_OPPORTUNITY_BONUS = 10;

    public static final Integer MAX_SCORE = 100;
    public static final Integer MIN_SCORE = 0;

    // Queueable
    public static final Integer CHUNK_SIZE = 200;
}