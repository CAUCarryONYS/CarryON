package Carrier.CarriOn;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
public class ChatMessageEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    private String content;

    @ManyToOne
    private UserEntity sender; // User 참조를 UserEntity로 변경

    @Enumerated(EnumType.STRING)
    private MessageType type;

    public enum MessageType {
        CHAT,
        JOIN,
        LEAVE
    }

    public ChatMessageEntity() {
    }
}
