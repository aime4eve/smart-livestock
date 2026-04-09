package com.smartlivestock.service.impl;

import com.smartlivestock.dto.UserDto;
import com.smartlivestock.entity.User;
import com.smartlivestock.exception.ResourceNotFoundException;
import com.smartlivestock.repository.UserRepository;
import com.smartlivestock.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 用户服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    
    /**
     * 创建新用户
     */
    @Override
    @Transactional
    public UserDto createUser(UserDto userDto) {
        // 检查用户名是否已存在
        if (userRepository.existsByUsername(userDto.getUsername())) {
            throw new IllegalArgumentException("用户名已存在: " + userDto.getUsername());
        }
        
        // 检查邮箱是否已存在
        if (userRepository.existsByEmail(userDto.getEmail())) {
            throw new IllegalArgumentException("邮箱已存在: " + userDto.getEmail());
        }
        
        // 创建用户实体
        User user = User.builder()
                .username(userDto.getUsername())
                .password(passwordEncoder.encode(userDto.getPassword())) // 加密密码
                .name(userDto.getName())
                .email(userDto.getEmail())
                .phone(userDto.getPhone())
                .role(userDto.getRole() != null ? userDto.getRole() : "viewer")
                .isActive(true)
                .build();
        
        // 保存用户
        User savedUser = userRepository.save(user);
        
        // 转换为DTO返回
        return mapToDto(savedUser);
    }
    
    /**
     * 根据ID获取用户
     */
    @Override
    @Transactional(readOnly = true)
    public UserDto getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        return mapToDto(user);
    }
    
    /**
     * 根据用户名获取用户
     */
    @Override
    @Transactional(readOnly = true)
    public UserDto getUserByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User", "username", username));
        return mapToDto(user);
    }
    
    /**
     * 获取所有用户
     */
    @Override
    @Transactional(readOnly = true)
    public List<UserDto> getAllUsers() {
        List<User> users = userRepository.findAll();
        return users.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }
    
    /**
     * 更新用户信息
     */
    @Override
    @Transactional
    public UserDto updateUser(Long id, UserDto userDto) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        
        // 如果更新用户名，检查是否与其他用户冲突
        if (!user.getUsername().equals(userDto.getUsername()) && 
                userRepository.existsByUsername(userDto.getUsername())) {
            throw new IllegalArgumentException("用户名已存在: " + userDto.getUsername());
        }
        
        // 如果更新邮箱，检查是否与其他用户冲突
        if (!user.getEmail().equals(userDto.getEmail()) && 
                userRepository.existsByEmail(userDto.getEmail())) {
            throw new IllegalArgumentException("邮箱已存在: " + userDto.getEmail());
        }
        
        // 更新用户信息
        user.setUsername(userDto.getUsername());
        user.setName(userDto.getName());
        user.setEmail(userDto.getEmail());
        user.setPhone(userDto.getPhone());
        
        // 如果提供了新密码，则更新密码
        if (userDto.getPassword() != null && !userDto.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(userDto.getPassword()));
        }
        
        // 保存更新后的用户
        User updatedUser = userRepository.save(user);
        
        return mapToDto(updatedUser);
    }
    
    /**
     * 删除用户
     */
    @Override
    @Transactional
    public void deleteUser(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        userRepository.delete(user);
    }
    
    /**
     * 检查用户名是否存在
     */
    @Override
    @Transactional(readOnly = true)
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }
    
    /**
     * 检查邮箱是否存在
     */
    @Override
    @Transactional(readOnly = true)
    public boolean existsByEmail(String email) {
        return userRepository.existsByEmail(email);
    }
    
    /**
     * 更新用户角色
     */
    @Override
    @Transactional
    public UserDto updateUserRole(Long id, String role) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        
        user.setRole(role);
        User updatedUser = userRepository.save(user);
        
        return mapToDto(updatedUser);
    }
    
    /**
     * 更新用户状态
     */
    @Override
    @Transactional
    public UserDto updateUserStatus(Long id, boolean isActive) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        
        user.setIsActive(isActive);
        User updatedUser = userRepository.save(user);
        
        return mapToDto(updatedUser);
    }
    
    /**
     * 更新最后登录时间
     */
    @Override
    @Transactional
    public UserDto updateLastLogin(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        
        user.setLastLogin(LocalDateTime.now());
        User updatedUser = userRepository.save(user);
        
        return mapToDto(updatedUser);
    }
    
    /**
     * 将实体转换为DTO
     */
    private UserDto mapToDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole())
                .isActive(user.getIsActive())
                .lastLogin(user.getLastLogin())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
} 