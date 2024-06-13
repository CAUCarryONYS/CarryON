package Carrier.CarriOn.Chat;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    List<ChatMessage> findByChatRoomId(Long chatRoomId);
    ChatMessage findFirstByChatRoomOrderByTimestampDesc(ChatRoom chatRoom);
}
