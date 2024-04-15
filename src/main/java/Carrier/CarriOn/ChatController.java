package Carrier.CarriOn;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.stereotype.Controller;

@Controller
public class ChatController {
    @MessageMapping("/chat.sendMessage")
    @SendTo("/topic/public")
    public ChatMessageEntity sendMessage(ChatMessageEntity chatMessage) {
        return chatMessage;
    }

    @MessageMapping("/chat.addUser")
    @SendTo("/topic/public")
    public ChatMessageEntity addUser(ChatMessageEntity chatMessage, SimpMessageHeaderAccessor headerAccessor) {
        // 사용자 세션에 이름 추가
        headerAccessor.getSessionAttributes().put("username", chatMessage.getSender().getName());
        return chatMessage;
    }
}
